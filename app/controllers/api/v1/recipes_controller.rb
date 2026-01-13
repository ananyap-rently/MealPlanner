# app/controllers/api/v1/recipes_controller.rb
module Api
  module V1
    class RecipesController < BaseController
      skip_before_action :doorkeeper_authorize!, only: [:index, :show]
      before_action :set_recipe, only: [:show, :update, :destroy]
      before_action :authorize_user!, only: [:update, :destroy]

      # Require write scope for destructive actions
      before_action -> { doorkeeper_authorize! :write }, only: [:create, :update, :destroy]

      # GET /api/v1/recipes
      # 
      def index
          recipes_scope = Recipe.includes(:user, :tags, :ingredients).order(created_at: :desc)
          
          # Paginate
          @pagy, @recipes = pagy(recipes_scope, page: params[:page], limit: params[:per_page])

          # Send pagination info in headers (your website ignores these for now)
          response.headers['X-Total-Count'] = @pagy.count.to_s
          response.headers['X-Total-Pages'] = @pagy.pages.to_s

          # Render JUST the array (This makes your website work again!)
          render json: @recipes.as_json(include: [:user, :tags, :ingredients])
        end
    #  def index
    #    recipes = Recipe.all
    #     # 1. Define the scope
    #     #recipes_scope = Recipe.includes(:user, :tags, :ingredients).order(created_at: :desc)
    #     @pagy, @recipe = pagy(recipes,
    #     page: params[:page],
    #     limit: params[:per_page])
    #     # 2. Paginate the scope
    #     # @pagy, @recipes = pagy(recipes_scope)

    #     # 3. Render structured JSON
    #     render json: {
    #        recipes: @recipe.as_json(include: [:user, :tags, :ingredients]),
    #       pagination: pagination_dict(@pagy)
    #     }
    #   end
     

      # GET /api/v1/recipes/:id
      def show
        render json: @recipe.as_json(
          include: {
            user: { only: [:id, :email] },
            tags: { only: [:id, :tag_name] },
            ingredients: { only: [:id, :name] },
            recipe_ingredients: { only: [:id, :ingredient_id, :quantity, :unit] },
            comments: { 
              include: { 
                user: { only: [:id, :email] } 
              } 
            }
          }
        )
      end

      # POST /api/v1/recipes
      def create
        @recipe = current_user.recipes.build(recipe_params)
        
        if @recipe.save
          render json: @recipe.as_json(
            include: {
              user: { only: [:id, :email] },
              tags: { only: [:id, :tag_name] },
              ingredients: { only: [:id, :name] },
              recipe_ingredients: { only: [:id, :ingredient_id, :quantity, :unit] }
            }
          ), status: :created, location: api_v1_recipe_url(@recipe)
        else
          render json: { errors: @recipe.errors.full_messages }, 
                 status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/recipes/:id
      def update
        if @recipe.update(recipe_params)
          render json: @recipe.as_json(
            include: {
              user: { only: [:id, :email] },
              tags: { only: [:id, :tag_name] },
              ingredients: { only: [:id, :name] },
              recipe_ingredients: { only: [:id, :ingredient_id, :quantity, :unit] }
            }
          )
        else
          render json: { errors: @recipe.errors.full_messages }, 
                 status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/recipes/:id
      def destroy
        @recipe.destroy
        head :no_content
      end

      private

      def recipe_params
        params.require(:recipe).permit(
          :title, 
          :instructions, 
          :prep_time, 
          :servings, 
          :new_tag_name,
          tag_ids: [], 
          recipe_ingredients_attributes: [
            :id, :ingredient_id, :quantity, :unit, :_destroy, :new_ingredient_name
          ]
        )
      end

      def set_recipe
        @recipe = Recipe.includes(:user, :tags, :ingredients, :recipe_ingredients, comments: :user)
                        .find(params[:id])
      end

      def authorize_user!
        unless @recipe.user == current_user
          render json: { error: "Not authorized" }, status: :forbidden
        end
      end
    end
  end
end