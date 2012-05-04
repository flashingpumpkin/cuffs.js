define ['cuffs/compiler', 'cuffs/template', 'cuffs/context', 'cuffs/bindings'], (compiler,{Template, Binding, render},{Context},bindings)->

    get = (name)->
        [$(name), $(name)[0]]

    describe 'Template', ->
        describe 'context', ->
            context = new Context {
                foo: 'bar'
                nested: { object: true }
            }
            it 'should return a context object', ->
                expect(context).not.to.be null
            it 'should have property lookup', ->
                expect(context.foo).to.be 'bar'
            it 'should have observers', ->
                checker = null
                context.watch 'foo', (value)->
                    checker = value
                context.set 'foo', 'baz'
                expect(checker).to.be 'baz'
            it 'should allow for nested lookups', ->
                expect(context.nested.object).to.be true
                expect(context.get('nested.object')).to.be true
                context.set 'nested.object', false
                expect(context.get('nested.object')).to.be false
            it 'should allow for nested watching', ->
                checker = null
                context.watch 'nested.object', (value)->
                    checker = value
                context.set 'nested.object', true
                expect(checker).to.be true

        describe 'binding', ->
            describe 'matching bindings', ->
                [_, node] = get '#matching-bindings'

                class DataBind1 extends Binding
                    @bind 'data-binding1'
                class DataBind2 extends Binding
                    @bind 'data-binding2'
                class DataBind3 extends Binding
                    @bind 'data-binding3'

                it 'should return all the attributes matched', ->
                    num = 0

                    compiler.walk node, (n)->
                        result = Binding.getBindings n
                        num += result.length

                    expect(num).to.be 3

            describe 'data-show', ->
                context = new Context { show: false }
                [$node, node] = get '#data-show'

                binding = new bindings.DataShow(node).applyContext(context)

                it 'should show elements', ->
                    expect($(node).is(':visible')).to.be false
                it 'should hide elements', ->
                    context.set 'show', true
                    expect($(node).is(':visible')).to.be true

            describe 'data-bind', ->
                describe 'html element', ->
                    context = new Context { bind: null }
                    [$node, node] = get '#data-bind'

                    binding = new bindings.DataBind(node).applyContext(context)

                    it 'should bind context changes', ->
                        context.set 'bind', 'Changed binding'
                        expect($node.html()).to.be 'Changed binding'

                describe 'text input', ->
                    context = new Context { bind: null }
                    [$node, node] = get '#data-bind-text'

                    binding = new bindings.DataBind(node).applyContext(context)

                    it 'should bind context changes', ->
                        context.set 'bind', 'Changed binding'
                        expect($node.val()).to.be 'Changed binding'
                    it 'should change the context', ->
                        $node.val 'Changed in template'
                        $node.change()
                        expect(context.bind).to.be 'Changed in template'

                describe 'checkboxes', ->
                    context = new Context { bind: false }
                    [$node, node] = get '#data-bind-checkbox'

                    binding = new bindings.DataBind(node).applyContext(context)

                    it 'should bind context changes', ->
                        context.set 'bind', true
                        expect($node.is(':checked')).to.be true
                        context.set 'bind', false
                        expect($node.is(':checked')).to.be false
                    it 'should change the context', ->
                        $node.attr 'checked', true
                        $node.change()
                        expect(context.bind).to.be true
                        $node.attr 'checked', false
                        $node.change()
                        expect(context.bind).to.be false

        describe 'data-set', ->
            context = new Context
            [$node, node] = get '#data-set'
            binding = new bindings.DataSet(node).applyContext(context)

            it 'should set the data on the context', ->
                expect(context.get('foo')).to.be('bar')

        describe 'data-activate', ->
            context = new Context {active: 'one'}
            [$node, node] = get '#data-activate'

            render(node, context)

            it 'should activate the right node', ->
                expect($(node.firstElementChild).hasClass('active')).to.be true
                expect($(node.lastElementChild).hasClass('active')).to.be false

            it 'should change the active status when the context changes', ->
                context.set 'active', 'two'
                expect($(node.firstElementChild).hasClass('active')).to.be false
                expect($(node.lastElementChild).hasClass('active')).to.be true

            it 'should react on clicks', ->
                $(node.firstElementChild).click()
                expect($(node.firstElementChild).hasClass('active')).to.be true
                expect($(node.lastElementChild).hasClass('active')).to.be false
                $(node.lastElementChild).click()
                expect($(node.firstElementChild).hasClass('active')).to.be false
                expect($(node.lastElementChild).hasClass('active')).to.be true

        describe 'data-attr', ->
            context = new Context title: 'Some title'
            [$node, node] = get '#data-attr'

            it 'should set the attributes on a node', ->
                new bindings.DataAttr(node).applyContext context
                expect($node.attr('title')).to.be 'Some title'

        describe 'data-or', ->
            context = new Context predicate: true
            [$node, node] = get '#data-or'

            it 'should set the content to "true" when the predicate is true', ->
                new bindings.DataOr(node).applyContext context
                expect($node.html()).to.be('true')
            it 'should set the content to "false" when the predicate is false', ->
                context.set 'predicate', false
                expect($node.html()).to.be('false')

        describe 'data-loop', ->
            context = new Context {
                name: "Frontend.js"
                musicians: [
                    { name: "Hendrix", visible: true }
                    { name: "Lennon", visible: true }
                ]
            }

            dom_template = document.getElementById 'dom_template'
            dom_template_name = document.getElementById 'dom_template_name'
            dom_template_musicians = document.getElementById 'dom_template_musicians'

            it 'should render a node with context', ->
                tpl = new Template(dom_template).applyContext context
                expect(dom_template_name.innerHTML).to.be 'Rendered with: <span data-bind="name">Frontend.js</span>'
                expect(dom_template_musicians.childElementCount).to.be 2
                expect(dom_template_musicians.firstElementChild.innerHTML.trim()).to.be '
                    Musician: <span data-bind="musician.name">Hendrix</span>'.trim()

            it 'should rerender when changing the context', ->
                context.set 'musicians', context.get('musicians').concat [
                    { name: 'Morrison', visible: false }
                ]
                expect(dom_template_musicians.childElementCount).to.be 3
                expect(dom_template_musicians.lastElementChild.innerHTML.trim()).to.be '
                    Musician: <span data-bind="musician.name">Morrison</span>'.trim()

            it 'should take into account additional bindings on loop root nodes', ->
                expect($(dom_template_musicians.lastElementChild).is(':visible')).to.be false

            it 'should be reasonably quick to render an array of 1000', ->
                musicians = []
                for i in [0..1000]
                    musicians.push name: "Musician #{i}", visible: Math.round(Math.random())
                context.set 'musicians', musicians

            it 'should be filterable', ->
                context.set 'musicians', context.get('musicians').map (m)->
                    m.visible = m.name.indexOf('0') > -1
                    m