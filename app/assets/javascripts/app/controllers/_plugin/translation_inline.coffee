class TranslationInline extends App.Controller
  constructor: ->
    super
    @rebind()
    @controllerBind('auth', => @rebind())
    @controllerBind('toggle-shortcut-layout', => @rebind())
    @controllerBind('i18n:inline_translation', => @toggle())

  rebind: =>
    $(document).off('keydown.translation')

    # only admins can do this
    return if !@permissionCheck('admin.translation')

    # bind on key down
    # if `t` is pressed, enable translation_inline and fire ui:rerender
    # in case of old shortcut layout, require hotkeys in the combination
    useOldShortcutLayout = App.KeyboardShortcutPlugin.useOldShortcutLayout()
    modifier = ''
    modifier += App.Browser.hotkeys() if useOldShortcutLayout
    modifier += '+' if modifier isnt ''
    modifier += 't'
    $(document).on('keydown.translation', { keys: modifier } , (e) =>
      return if App.KeyboardShortcutPlugin.isDisabled()
      return if App.KeyboardShortcutPlugin.isInput()

      e.preventDefault()
      @toggle()
    )

  toggle: =>
    if @active
      $('.translation:focus').trigger('blur')
      @disable()
      @active = false
      return

    @enable()
    @active = true

  enable: ->
    # load in collection if needed
    meta = App.i18n.meta()
    if !@mapLoaded && meta && meta.mapToLoad
      @mapLoaded = true
      App.Translation.refresh(meta.mapToLoad, {clear: true} )

    # enable translation inline
    App.Config.set('translation_inline', true)

    @observer = new MutationObserver((mutations) ->

      mutations.forEach((mutation) ->

        mutation.addedNodes.forEach((addedNode) ->

          $(addedNode).find('span.translation').on('click.translation', (e) ->
            e.stopPropagation()
            return false
          )
          $(addedNode).find('span.translation').on('keydown.translation', (e) ->
            e.stopPropagation()
            return true
          )
        )

        mutation.removedNodes.forEach((removedNode) ->
          $(removedNode).find('span.translation').off('.translation')
        )
      )
    )

    @observer.observe(document.body, {
      subtree:   true,
      childList: true,
    })

    # rerender controllers
    App.Event.trigger('ui:rerender')

    # observe if text has been translated
    $('body')
      .on 'focus.translation', '.translation', (e) ->
        element = $(e.target)
        element.data 'before', element.text()
        element
      .on 'blur.translation', '.translation', (e) ->
        element = $(e.target)
        source = element.attr('title')
        return if !source

        # get new translation
        translation_new = element.text()

        # update translation
        return if element.data('before') is translation_new
        App.Log.debug 'translation_inline', 'translate update', translation_new, 'before', element.data
        element.data 'before', translation_new

        # update runtime translation mapString
        App.i18n.setMap(source, translation_new)

        # replace rest in page
        sourceQuoted = source.replace('\'', '\\\'')
        $(".translation[title='#{sourceQuoted}']").text(translation_new)

        # update permanent translation mapString
        translation = App.Translation.findByAttribute('source', source)
        if translation
          translation.updateAttribute('target', translation_new)
        else
          translation = new App.Translation
          translation.load(
            locale:         App.i18n.get()
            source:         source
            target:         translation_new
            target_initial: ''
          )
          translation.save()

        element

  disable: ->
    @observer.disconnect()

    $('body').off('.translation')

    # disable translation inline
    App.Config.set('translation_inline', false)

    # rerender controllers
    App.Event.trigger('ui:rerender')

App.Config.set('translation_inline', TranslationInline, 'Plugins')
