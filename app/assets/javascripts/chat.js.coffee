jQuery ->
  window.chatController = new Chat.Controller($('#chat').data('uri'), true);

window.Chat = {}

class Chat.User
  constructor: (@nick_name) ->
  serialize: => { nick_name: @nick_name }

class Chat.Controller
  constructor: (url,useWebSockets) ->
    @messageQueue = []
    @dispatcher = new WebSocketRails(url,useWebSockets)
    @dispatcher.on_open = @createGuestUser
    @bindEvents()

  bindEvents: =>
    @dispatcher.bind 'new_message', @newMessage
    @dispatcher.bind 'user_list', @updateUserList
    $('input#nick_name').on 'keyup', @updateUserInfo
    $('#send').on 'click', @sendMessage
    $('#message').keypress (e) -> $('#send').click() if e.keyCode == 13

  template: (message) ->
    html =
    """
      <div class='message' >
        #{message.received}
        <span class="#{message.nick_name}">
          #{message.nick_name}
        </span>&nbsp;
        <span class='text-info'> #{message.msg_body}</span>
      </div>
      """
    $(html)

  userListTemplate: (userList) ->
    userHtml = ""
    for user in userList
      userHtml = userHtml + "<li>#{user.nick_name}</li>"
    $(userHtml)

  newMessage: (message) =>
    @messageQueue.push message
    @shiftMessageQueue() if @messageQueue.length > 15
    @appendMessage message

  sendMessage: (event) =>
    event.preventDefault()
    message = $('#message').val()
    @dispatcher.trigger 'new_message', {nick_name: @user.nick_name, msg_body: message}
    $('#message').val('')

  updateUserList: (userList) =>
    $('#user-list').html @userListTemplate(userList)

  updateUserInfo: (event) =>
    @user.nick_name = $('input#nick_name').val()
    $('#username').html @user.nick_name
    $("span."+localStorage.getItem("old_nick_name")).html @user.nick_name
    @dispatcher.trigger 'change_username', @user.serialize()

  appendMessage: (message) ->
    messageTemplate = @template(message)
    $('#chat').append messageTemplate
    messageTemplate.slideDown 100

  shiftMessageQueue: =>
    @messageQueue.shift()
    $('#chat div.messages:first').slideDown 100, ->
      $(this).remove()

  createGuestUser: =>
    rand_num = Math.floor(Math.random()*1000)
    @user = new Chat.User("Guest_" + rand_num)
    $('#username').html @user.nick_name
    $('input#nick_name').val @user.nick_name
    @dispatcher.trigger 'new_user', @user.serialize()
    localStorage.setItem("old_nick_name", $('input#nick_name').val())


