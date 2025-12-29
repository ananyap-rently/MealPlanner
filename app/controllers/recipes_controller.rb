class RecipesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_recipe, only: [:show, :edit, :update, :destroy]
  before_action :authorize_user!, only: [:edit, :update, :destroy]
  def index
    @recipes = Recipe.all
  end

  def show
    @comments = @recipe.comments.includes(:user)
    @comment = Comment.new
  end

  def new
  @recipe = Recipe.new
  end
  def edit

  end
  def create
    @recipe = current_user.recipes.build(recipe_params)
    if @recipe.save
      redirect_to @recipe, notice: "Recipe created!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @recipe.update(recipe_params)
      redirect_to @recipe, notice: "Recipe updated successfully!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @recipe.destroy
    redirect_to recipes_path, notice: "Recipe deleted", status: :see_other
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
      recipe_ingredients_attributes: [:id, :ingredient_id, :quantity, :unit, :_destroy, :new_ingredient_name]
    )
  end

  def set_recipe
    @recipe = Recipe.find(params[:id])
  end

  def authorize_user!
    if @recipe.user != current_user
      redirect_to recipes_path, alert: "You are not authorized to perform this action"
    end
  end
end