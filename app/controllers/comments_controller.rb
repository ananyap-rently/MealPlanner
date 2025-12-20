class CommentsController < ApplicationController
    def create
        @commentable = find_commentable
        @comment = @commentable.comments.build(comment_params)
        @comment.user = current_user
        @comment.save
        redirect_to @commentable
    #     @meal_plan = MealPlan.find(params[:meal_plan_id])
    # @comment = @meal_plan.comments.build(comment_params)
    

    
    end

    def destroy
        @comment = Comment.find(params[:id])
        @commentable = @comment.commentable
        @comment.destroy
        redirect_to @commentable, notice: "Comment deleted successfully"
    end
    private

    def find_commentable
        params.each do |name, value|
            if name =~ /(.+)_id$/
                return $1.classify.constantize.find(value)
            end
        end
    end

    def comment_params
        params.require(:comment).permit(:content)
    end
end