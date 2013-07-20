# OAuth driver that uses a Cordova InAppBrowser to complete the flow.
class Dropbox.AuthDriver.Cordova extends Dropbox.AuthDriver.BrowserBase
  # Sets up an OAuth driver for Cordova applications.
  #
  # @param {Object} options (optional) one of the settings below
  # @option options {String} scope embedded in the localStorage key that holds
  #   the authentication data; useful for having multiple OAuth tokens in a
  #   single application
  # @option options {Boolean} rememberUser if false, the user's OAuth tokens
  #   are not saved in localStorage; true by default
  constructor: (options) ->
    if options
      @rememberUser = if 'rememberUser' of options
        options.rememberUser
      else
        true
      @scope = options.scope or 'default'
    else
      @rememberUser = true
      @scope = 'default'
    @scope = options?.scope or 'default'

  # URL of the page that the user will be redirected to.
  #
  # @return {String} always the signed-in user homepage; the user must be
  #   signed in to grant access to the app
  # @see Dropbox.AuthDriver#url
  url: ->
    'https://www.dropbox.com/home'

  # Shows the authorization URL in a pop-up, waits for it to send a message.
  #
  # @see Dropbox.AuthDriver#doAuthorize
  doAuthorize: (authUrl, stateParam, client, callback) ->
    browser = window.open authUrl, '_blank', 'location=yes'
    promptPageLoaded = false
    authHost = /^[^/]*\/\/[^/]*\//.exec(authUrl)[0]
    onEvent = (event) ->
      if event.url and @locationStateParam(event.url) is stateParam
        browser.removeEventListener 'loadstop', onEvent
        browser.removeEventListener 'exit', onEvent
        browser.close() unless event.type is 'exit'
        callback Dropbox.Util.Oauth.queryParamsFromUrl event.url

      if event.type is 'exit'
        browser.removeEventListener 'loadstop', onEvent
        browser.removeEventListener 'exit', onEvent
        browser.close() unless event.type is 'exit'
        # TODO(pwnall): exit callback
        callback()

    browser.addEventListener 'loadstop', onEvent
    browser.addEventListener 'exit', onEvent
