class UserMailer < ActionMailer::Base
  include UrlOverrideHelper

  def signup_notification(user)
    setup_email(user, Topic.default)
    @subject    += 'Please activate your new account'
  
    @body[:url]  = "http://#{Topic.default.subdomain}.welltreat.us/activate/#{user.activation_code}"
    @body[:topic] = Topic.default
  end
  
  def activation(user)
    setup_email(user, Topic.default)

    @subject    += 'Your account has been activated!'
    @body[:url]  = "http://#{Topic.default.subdomain}.welltreat.us/"
    @body[:topic] = Topic.default
  end

  def reset_password(user)
    topic = nil
    if user.user_logs.last
      topic = user.user_logs.last.topic
    else
      topic = Topic.default
    end

    setup_email(user, topic)

    @subject += 'Your password change request!'
    @body[:url] = change_password_url(user.remember_token,
                                      :subdomain => topic.subdomain)

    @body[:topic] = topic
  end

  def comment_notification(review_comment)
    setup_email(review_comment.review.user, review_comment.topic)
    @subject += "#{review_comment.user.login} has commented on your review at '#{review_comment.restaurant.name}'"
    @body[:review_comment] = review_comment
    @body[:url] = restaurant_long_route_url(
        :topic_name => review_comment.topic.subdomain,
        :name => review_comment.restaurant.name.parameterize.to_s,
        :id => review_comment.restaurant.id,
        :subdomain => review_comment.topic.subdomain)
    @body[:topic] = review_comment.topic
  end

  def review_notification(review)
    setup_email(review.restaurant.user, review.topic)
    @subject += "#{review.user.login} has reviewed your #{review.topic.subdomain} '#{review.restaurant.name}'"
    @body[:review] = review
    @body[:url] = restaurant_long_route_url(
        :topic_name => review.topic.subdomain,
        :name => review.restaurant.name.parameterize.to_s,
        :id => review.restaurant.id,
        :subdomain => review.topic.subdomain)
    @body[:topic] = review.topic
  end

  protected
    def setup_email(user, topic)
      @recipients  = "#{user.email}"
      @from        = "notification"
      @subject     = "[#{topic ? topic.subdomain : 'www'}.welltreat.us] "
      @sent_on     = Time.now
      @body[:user] = user
    end
end
