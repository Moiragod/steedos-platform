@urlQuery = new Array()
checkUserSigned = (context, redirect) ->
	return
	# listTreeCompany = localStorage.getItem("listTreeCompany")
	# if listTreeCompany
	# 	Session.set('listTreeCompany', listTreeCompany);
	# else
	# 	# 从当前用户的space_users表中获取
	# 	s_user = db.space_users.findOne()
	# 	if s_user?.company
	# 		localStorage.setItem("listTreeCompany", s_user?.company)
	# 		Session.set('listTreeCompany', s_user?.company);
	# 	else
	# 		# Session.set('listTreeCompany', "-1");
	# 		Session.set('listTreeCompany', "xZXy9x8o6qykf2ZAf");
	# 统一设置此参数，待以后拆分
	# Session.set('listTreeCompany', "xZXy9x8o6qykf2ZAf")
	
	# if !Meteor.userId()
	# 	Setup.validate();

set_sessions = (context, redirect)->
	app_id = context.params.app_id
	if (app_id != "-")
		Session.set("app_id", app_id)
	Session.set("object_name", context.params.object_name)
	Session.set("record_id", context.params.record_id)

checkAppPermission = (context, redirect)->
	app_id = context.params.app_id
	if app_id == "admin" || app_id == "-"
		return
	apps = _.pluck(Creator.getVisibleApps(true),"_id")
	if apps.indexOf(app_id) < 0
		console.log(app_id + " app access denied")
		Session.set("app_id", Creator.getVisibleApps(true)[0]._id)
		redirect "/"

checkObjectPermission = (context, redirect)->
	object_name = context.params.object_name
	allowRead = Creator.getObject(object_name)?.permissions?.get()?.allowRead
	unless allowRead
		console.log(object_name + " object access denied")
		Session.set("object_name", null)
		redirect "/"


FlowRouter.route '/app',
	triggersEnter: [ checkUserSigned ],
	action: (params, queryParams)->
		BlazeLayout.render Creator.getLayout(),
			main: "creator_app_home"

FlowRouter.route '/app/menu',
	triggersEnter: [ checkUserSigned ],
	action: (params, queryParams)->
		return

FlowRouter.route '/app/:app_id',
	triggersEnter: [ checkUserSigned, checkAppPermission ],
	action: (params, queryParams)->
		app_id = FlowRouter.getParam("app_id")
		if (app_id != "-")
			Session.set("app_id", app_id)
		Session.set("admin_template_name", null)
		if FlowRouter.getParam("app_id") is "meeting"
			FlowRouter.go('/app/' + app_id + '/meeting/calendar')
		else
			main = 'creator_app_home'
			if Steedos.isMobile()
				Session.set('hidden_header', true)
				main = 'app_object_menu'
			BlazeLayout.render Creator.getLayout(),
				main: main
	triggersExit: [(context, redirect) ->
		if Steedos.isMobile()
			Session.set("hidden_header", undefined)
	]

FlowRouter.route '/app/:app_id/home',
	triggersEnter: [ checkUserSigned, checkAppPermission ],
	action: (params, queryParams)->
		app_id = FlowRouter.getParam("app_id")
		Session.set("app_id", app_id)
		Session.set("admin_template_name", null)
		Session.set("app_home_active", true)
		if FlowRouter.getParam("app_id") is "meeting"
			FlowRouter.go('/app/' + app_id + '/meeting/calendar')
		else
			main = 'dashboard'
			if Steedos.isMobile()
				Session.set('hidden_header', true)
				main = 'dashboard'
			BlazeLayout.render Creator.getLayout(),
				main: main
	triggersExit: [(context, redirect) ->
		Session.set("app_home_active", false);
		if Steedos.isMobile()
			Session.set("hidden_header", undefined)
	]

FlowRouter.route '/user_settings',
	triggersEnter: [ checkUserSigned ],
	action: (params, queryParams)->
			Session.set('headerTitle', '设置' )
			Session.set("showBackHeader", true)
			BlazeLayout.render Creator.getLayout(),
					main: "adminMenu"
	triggersExit: [(context, redirect) ->
		Session.set("showBackHeader", false)
		Session.set('headerTitle', undefined )
	]


FlowRouter.route '/user_settings/switchspace',
	triggersEnter: [ checkUserSigned ],
	action: (params, queryParams)->
			Session.set('headerTitle', '选择工作区')
			Session.set("showBackHeader", true)
			BlazeLayout.render Creator.getLayout(),
				main: "switchSpace"
	triggersExit: [(context, redirect) ->
		Session.set("showBackHeader", false)
		Session.set('headerTitle', undefined )
	]

FlowRouter.route '/app/:app_id/search/:search_text',
	triggersEnter: [ checkUserSigned ],
	action: (params, queryParams)->
		app_id = FlowRouter.getParam("app_id")
		if (app_id != "-")
			Session.set("app_id", app_id)
		Session.set("search_text", FlowRouter.getParam("search_text"))
		Session.set("record_id", null) #有的地方会响应Session中record_id值，如果不清空可能会有异常现象，比如删除搜索结果中的记录后会跳转到记录对应的object的列表
		BlazeLayout.render Creator.getLayout(),
			main: "record_search_list"

FlowRouter.route '/app/:app_id/reports/view/:record_id',
	triggersEnter: [ checkUserSigned ],
	action: (params, queryParams)->
		app_id = FlowRouter.getParam("app_id")
		record_id = FlowRouter.getParam("record_id")
		object_name = FlowRouter.getParam("object_name")
		if (app_id != "-")
			Session.set("app_id", app_id)
		data = {app_id: Session.get("app_id"), record_id: record_id, object_name: object_name}
		Session.set("object_name", "reports")
		Session.set("record_id", record_id)
		BlazeLayout.render Creator.getLayout(),
			main: "creator_report"

FlowRouter.route '/app/:app_id/instances/grid/all',
	action: (params, queryParams)->
		app_id = FlowRouter.getParam("app_id")
		if (app_id != "-")
			Session.set("app_id", app_id)
		Session.set("object_name", "instances")
		FlowRouter.go '/workflow'
		return

objectRoutes = FlowRouter.group
	prefix: '/app/:app_id/:object_name',
	name: 'objectRoutes',
	triggersEnter: [checkUserSigned, checkAppPermission, checkObjectPermission, set_sessions]

objectRoutes.route '/',
	triggersEnter: [ 
		# 自动跳转到对象的第一个视图
		(context, redirect) -> 
			object_name = context.params.object_name
			objectHomeComponent = ReactSteedos.pluginComponentSelector(ReactSteedos.store.getState(), "ObjectHome", object_name)
			unless objectHomeComponent
				list_view = Creator.getObjectFirstListView(object_name)
				list_view_id = list_view?._id
				app_id = context.params.app_id
				if object_name == "meeting"
					url = "/app/" + app_id + "/" + object_name + "/calendar/"
				else
					url = "/app/" + app_id + "/" + object_name + "/grid/" + list_view_id
				redirect(url)
	 ],
	action: (params, queryParams)->
		BlazeLayout.render Creator.getLayout(),
			main: "object_home"

#objectRoutes.route '/list/switch',
#	action: (params, queryParams)->
#		if Steedos.isMobile()  && false and $(".mobile-content-wrapper #list_switch").length == 0
#			Tracker.autorun (c)->
#				if Creator.bootstrapLoaded.get() and Session.get("spaceId")
#					c.stop()
#					app_id = FlowRouter.getParam("app_id")
#					object_name = FlowRouter.getParam("object_name")
#					data = {app_id: app_id, object_name: object_name}
#					Meteor.defer ->
#						Blaze.renderWithData(Template.listSwitch, data, $(".mobile-content-wrapper")[0], $(".layout-placeholder")[0])

#objectRoutes.route '/:list_view_id/list',
#	action: (params, queryParams)->
#		app_id = FlowRouter.getParam("app_id")
#		object_name = FlowRouter.getParam("object_name")
#		list_view_id = FlowRouter.getParam("list_view_id")
#		data = {app_id: app_id, object_name: object_name, list_view_id: list_view_id}
#		Session.set("reload_dxlist", false)
#		if Steedos.isMobile()  && false and $("#mobile_list_#{object_name}").length == 0
#			Tracker.autorun (c)->
#				if Creator.bootstrapLoaded.get() and Session.get("spaceId")
#					c.stop()
#					Meteor.defer ->
#						Blaze.renderWithData(Template.mobileList, data, $(".mobile-content-wrapper")[0], $(".layout-placeholder")[0])

objectRoutes.route '/:record_id/:related_object_name/grid',
	action: (params, queryParams)->
		app_id = Session.get("app_id")
		object_name = FlowRouter.getParam("object_name")
		record_id = FlowRouter.getParam("record_id")
		related_object_name = FlowRouter.getParam("related_object_name")
		data = {app_id: app_id, object_name: object_name, record_id: record_id, related_object_name: related_object_name}
		Session.set 'related_object_name', related_object_name
		BlazeLayout.render Creator.getLayout(),
			main: "related_object_list"

objectRoutes.route '/view/:record_id',
	action: (params, queryParams)->
		app_id = FlowRouter.getParam("app_id")
		object_name = FlowRouter.getParam("object_name")
		record_id = FlowRouter.getParam("record_id")
		data = {app_id: app_id, object_name: object_name, record_id: record_id}
		ObjectRecent.insert(object_name, record_id)
		Session.set("detail_info_visible", true)
		if object_name == "users"
			main = "user"
		else
			main = "creator_view"
		BlazeLayout.render Creator.getLayout(),
			main: main

objectRoutes.route '/grid/:list_view_id',
	action: (params, queryParams)->
		Session.set("record_id", null)
		if Session.get("object_name") != FlowRouter.getParam("object_name")
			Session.set("list_view_id", null)

		if queryParams?.hidden_header=="true"
			Session.set("hidden_header", true)

		app_id = FlowRouter.getParam("app_id")
		if (app_id != "-")
			Session.set("app_id", app_id)
		Session.set("object_name", FlowRouter.getParam("object_name"))
		Session.set("list_view_id", FlowRouter.getParam("list_view_id"))
		Session.set("list_view_visible", false)

		Tracker.afterFlush ()->
			Session.set("list_view_visible", true)
		
		BlazeLayout.render Creator.getLayout(),
			main: "creator_list_wrapper"

objectRoutes.route '/calendar/',
	action: (params, queryParams)->
		if Session.get("object_name") != FlowRouter.getParam("object_name")
			Session.set("list_view_id", null)

		app_id = FlowRouter.getParam("app_id")
		if (app_id != "-")
			Session.set("app_id", app_id)
		Session.set("object_name", FlowRouter.getParam("object_name"))
		Session.set("list_view_visible", false)

		Tracker.afterFlush ()->
			Session.set("list_view_visible", true)
		
		BlazeLayout.render Creator.getLayout(),
			main: "creator_calendar"

FlowRouter.route '/app/admin/page/:template_name', 
	triggersEnter: [ checkUserSigned ],
	action: (params, queryParams)->
		template_name = params?.template_name
		if Meteor.userId()
			Session.set("app_id", "admin")
			Session.set("admin_template_name", template_name)
			BlazeLayout.render Creator.getLayout(),
				main: template_name
