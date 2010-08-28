module ModuleReviewHelper

  KEY_RECENT_REVIEWS = 'recent_reviews'

  def edit_recent_reviews(options = {})
    element = template_element(options, KEY_RECENT_REVIEWS)
    editor = render(:partial => "reviews/modules/edit_recent_reviews",
                    :object => element)
    viewable = recent_reviews(options)

    "#{editor}<div class='space_10'></div>#{viewable}"
  end

  def recent_reviews(options = {})
    recent_reviews = load_recent_reviews(options)
    render :partial => 'reviews/modules/recent_reviews', 
           :locals => {:recent_reviews => recent_reviews}
  end

  private
    def load_recent_reviews(options)
      element = template_element(options, KEY_RECENT_REVIEWS)
      max = (element.data || [{}]).first['max'].to_i

      @restaurant.reviews.all(:limit => max)
    end
end
