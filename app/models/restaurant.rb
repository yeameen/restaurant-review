class Restaurant < ActiveRecord::Base

  serialize :properties

  belongs_to :user
  belongs_to :topic
  has_many :related_images, :order => 'created_at DESC', :dependent => :destroy
  has_many :images, :through => :related_images, :dependent => :destroy
  has_many :contributed_images, :order => 'created_at DESC', :dependent => :destroy
  has_many :other_images, :through => :contributed_images, :source => :image, :dependent => :destroy
  has_many :reviews
  has_many :stuff_events
  has_many :subscribers, :source => :user, :through => :stuff_events

  validates_presence_of :name, :topic_id
  validate :form_attributes_required_fields

  named_scope :recent, :order => 'created_at DESC'
  named_scope :by_topic, lambda{|topic_id| {:conditions => {:topic_id => topic_id}}}

  cattr_reader :per_page
  @@per_page = 20

  NO_LIMIT = -1

  def author?(p_user)
    return p_user && p_user.id == self.user.id
  end

  #
  # Retrieve most loved restaurants based on the highest number of 'loved' rate
  # Use +p_limit+ option to limit the row set.
  # If +-1+ is given it will limit the row sets based on class attribute +:per_page+
  #
  def self.most_loved(p_topic, p_limit = 5, p_offset = 0)
    limit = determine_row_limit_option(p_limit)

    reviews = Review.by_topic(p_topic.id).loved.find(:all, {
        :include => [:restaurant],
        :group => 'restaurant_id',
        :order => 'count(restaurant_id) DESC',
        :offset => p_offset,
        :limit => limit})
    reviews.collect{|r| r.restaurant}
  end

  def self.count_most_loved
    Review.loved.count
  end

  def self.recently_reviewed(p_topic, p_limit = 5, p_offset = 0)
    limit = determine_row_limit_option(p_limit)

    reviews = Review.by_topic(p_topic.id).recent.find(:all, {
        :include => [:restaurant],
        :offset => p_offset,
        :limit => limit})
    reviews.collect{|r| r.restaurant}
  end

  def self.recently_added_pictures(p_limit = 5, p_offset = 0)
    limit = determine_row_limit_option(p_limit)

    images = Image.recent.find(:all, {
        :conditions => 'parent_id IS NULL',
        :order => 'images.created_at DESC',
        :offset => p_offset,
        :limit => limit})

    restaurants = images.collect do |image|
      image.contributed_images.first.restaurant if image.contributed_images.first
      image.related_images.first.restaurant if image.related_images.first
    end

    restaurants.compact
  end

  def self.count_recently_reviewed
    Review.count
  end

  def last_review
    reviews.find(:first, :order => 'id DESC')
  end

  def reviewed?(p_user)
    if p_user
      reviews.count(:conditions => {:user_id => p_user.id}) > 0
    end
  end

  private
    def self.determine_row_limit_option(p_limit)
      if p_limit == -1
        per_page
      else
        p_limit
      end
    end

  protected
    def form_attributes_required_fields
      if topic && topic.form_attribute
        form_attributes = topic.form_attribute

        # Ensure record input limit match
        ensure_record_insert_limit_doesnt_exceeds(form_attributes)

        # Ensure required fields are maintained
        ensure_required_fields_are_not_empty(form_attributes)
      end
    end

    def ensure_required_fields_are_not_empty(form_attributes)
      form_attributes.fields.each do |field|
        if field['required'] == true || field['required'].to_i == 1
          if self.send(field['field']).nil? || self.send(field['field']).empty?
            errors.add(field['field'], "can't be blank")
          end
        end
      end
    end

    def ensure_record_insert_limit_doesnt_exceeds(form_attributes)
      if form_attributes.record_insert_type == FormAttribute::SINGLE_RECORD
        existing_record = Restaurant.find(:first, :conditions => {
            :topic_id => self.topic_id,
            :user_id => self.user_id})
        if existing_record
          errors.add_to_base("Existing record found")
        end
      end
    end


end
