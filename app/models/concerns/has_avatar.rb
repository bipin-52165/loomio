module HasAvatar
  include AvatarInitials
  include Routing
  extend ActiveSupport::Concern

  included do
    include Gravtastic
    gravtastic rating: :pg, default: :none
    before_create :set_default_avatar_kind
  end

  def set_default_avatar_kind
    self.avatar_kind = :gravatar if !uploaded_avatar.attached? && has_gravatar?
  end

  def avatar_kind
    return 'mdi-duck' if deactivated_at?
    return 'mdi-email-outline' if !name
    super
  end

  def thumb_url
    avatar_url(128)
  end

  def avatar_url(size = 512)
    case avatar_kind.to_sym
    when :gravatar
      gravatar_url(size: size, secure: true, default: 'retro')
    when :uploaded && uploaded_avatar.attached?
      Rails.application.routes.url_helpers.rails_representation_path( uploaded_avatar.representation(resize: "#{size}x#{size}"), only_path: true )
    else
      nil
    end
  end

  def has_gravatar?(options = {})
    return false if Rails.env.test?
    hash = Digest::MD5.hexdigest(email.to_s.downcase)
    options = { :rating => 'x', :timeout => 2 }.merge(options)
    http = Net::HTTP.new('www.gravatar.com', 80)
    http.read_timeout = options[:timeout]
    response = http.request_head("/avatar/#{hash}?rating=#{options[:rating]}&default=http://gravatar.com/avatar")
    response.code != '302'
  rescue StandardError, Timeout::Error
    false  # Don't show "gravatar" if the service is down or slow
  end

end
