class ChatController < WebsocketRails::BaseController
  include ActionView::Helpers::SanitizeHelper

  def initialize_session
  end

  def system_msg(ev, msg)
    broadcast_message ev, {
        nick_name: 'System',
        received: Time.now.to_s(:short),
        msg_body: msg
    }
  end

  def user_msg(ev, msg)
    broadcast_message ev, {
        nick_name:  connection_store[:user][:nick_name],
        received:   Time.now.to_s(:short),
        msg_body:   ERB::Util.html_escape(msg)
    }
  end

  def client_connected
    system_msg :new_message, "User with id: #{client_id} connected"
  end

  def new_message
    user_msg :new_message, message[:msg_body].dup
  end

  def new_user
    connection_store[:user] = { nick_name: sanitize(message[:nick_name]) }
    broadcast_user_list
  end

  def change_username
    connection_store[:user][:nick_name] = sanitize(message[:nick_name])
    broadcast_user_list
  end

  def client_disconnected
    connection_store[:user] = nil
    system_msg:new_message, "User with id: #{client_id} disconnected"
    broadcast_user_list
  end

  def broadcast_user_list
    users = connection_store.collect_all(:user)
    broadcast_message :user_list, users
  end

end