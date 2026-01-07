# app/controllers/api/v1/ingredients_controller.rb
module Api
  module V1
    class IngredientsController < BaseController
      skip_before_action :authenticate_user!, only: [:index, :show]

      # GET /api/v1/ingredients
      def index
        @ingredients = Ingredient.all.order(:name)
        render json: @ingredients
      end

      # GET /api/v1/ingredients/:id
      def show
        @ingredient = Ingredient.find(params[:id])
        render json: @ingredient
      end

      # POST /api/v1/ingredients
      def create
        @ingredient = Ingredient.new(ingredient_params)

        if @ingredient.save
          render json: @ingredient, status: :created
        else
          render json: { errors: @ingredient.errors.full_messages }, 
                 status: :unprocessable_entity
        end
      end

      private

      def ingredient_params
        params.require(:ingredient).permit(:name)
      end
    end
  end
end