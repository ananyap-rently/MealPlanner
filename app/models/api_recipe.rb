class ApiRecipe
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :id, :title, :instructions, :prep_time, :servings, 
                :recipe_ingredients, :tag_ids, :new_tag_name, 
                :user, :user_id, :created_at, :updated_at

  def initialize(attributes = {})
    # 1. Default to an empty hash if attributes is nil
    attributes ||= {}

    # 2. Filter attributes
    allowed_attributes = attributes.select { |k, _| respond_to?("#{k}=") }
    
    # 3. Pass the hash to super
    super(allowed_attributes)
    
    # 4. Handle nested logic safely
    setup_nested_ingredients
  end # <--- Closes initialize

  def persisted?
    id.present?
  end

  def new_record?
    id.nil?
  end

  private

  def setup_nested_ingredients
    @recipe_ingredients ||= []
    if @recipe_ingredients.is_a?(Array) && @recipe_ingredients.any? && @recipe_ingredients.first.is_a?(Hash)
      @recipe_ingredients = @recipe_ingredients.map { |ri| OpenStruct.new(ri) }
    end
  end # <--- Closes setup_nested_ingredients

end # <--- Closes class ApiRecipe (THIS IS LIKELY MISSING)