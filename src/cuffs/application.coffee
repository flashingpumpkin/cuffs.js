define (require)->
    Cuffs      = require './ns'
    {walk}     = require './compiler'
    Context    = require './context'
    {Template} = require './template'


    # Looks up objects on the global classpath, eg:
    # lookup('window.document.body')
    lookup = (classpath)->
        parts = classpath.split '.'
        current = this

        for part in parts
            current = current[part]

            if not current?
                throw new Error "Not found: #{classpath}"

        current

    class Application
        @__id__: 0

        # Generates and returns global unique ids
        @id: -> ++ Application.__id__

        # Used for lookup up controller instances by id
        _controller_ids: {}

        # Used for looking up contexts by controller id 
        _controller_context_ids: {}

        # Used for looking up controller instances by their
        # constructor
        _controller_ctor: {}


        # Used for looking up controller by name
        _controller_names: {}

        constructor: (@node, @callback = (->))->
            @context = new Context
            @initControllers()
            @initTemplate()
            @callback()

        initControllers: ()->
            # Init all the controllers. We assume that they are
            # objects with a constructor. Functions would do too
            # though. If the resulting object has a .init method call
            # it after all controllers have been constructed.

            walk @node, (node, depth)=>
                return if node.nodeType != Node.ELEMENT_NODE
                return if not classpath = node.getAttribute 'data-controller'

                id = Application.id()
                context = @getParentContext(node).new()
                Controller = lookup classpath
                controller = new Controller app: this, context: context

                @_controller_ids[id] = controller
                @_controller_context_ids[id] = context
                @_controller_ctor[Controller] = controller
                @_controller_names[classpath] = controller

                $(node).attr('data-controller-id', id)

            for own id, ctrl of @_controller_ids
                ctrl.init() if ctrl.init?

        initTemplate: ()->
            # Make the DOM ready to rumble
            @template = new Template(@node)
            @template.applyContext (node)=>
                    @getParentContext node


        getParentContext: (node)->
            # Return the parent context of a DOM node
            if not node?
                return @context
            if node.nodeType == Node.TEXT_NODE
                return @getParentContext node.parentElement
            if id = node.getAttribute('data-controller-id')
                return @_controller_context_ids[id]
            while node = node.parentElement
                break if not node?
                if id = node.getAttribute('data-controller-id')
                    return @_controller_context_ids[id]
            return @context

        getController: (Controller)->
            # Return a controller by constructor
            @_controller_ctor[Controller]

        getControllerById: (id)->
            # Return a controller by id
            @_controller_ids[id]

        getControllerByName: (name)->
            # Return a controller by classpath
            @_controller_names[name]

        @start: (callback)->
            # Start all applications. If a callback is provided, call
            # it after everything is done.
            Cuffs.apps = $('[data-app]').map ->
                new Application this, callback

    return Cuffs.Application =  Application
