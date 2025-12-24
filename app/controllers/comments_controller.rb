class CommentsController < ApplicationController
     before_action :authenticate_user! 
    def create
        @commentable = find_commentable
        @comment = @commentable.comments.build(comment_params)
        @comment.user = current_user
        @comment.save
        redirect_to @commentable
    
    end

    def destroy
        @comment = Comment.find(params[:id])
        @commentable = @comment.commentable
        @comment.destroy
        redirect_to @commentable, notice: "Comment deleted successfully"
    end
    private

    def find_commentable
        # params.each do |name, value|
        #     if name =~ /(.+)_id$/
        #         return $1.classify.constantize.find(value)
        #     end
        # end
         params.each_pair do |key, value|
      if (match = key.match(/(.+)_id$/))
        return match[1].classify.constantize.find(value)
      end
    end
    end

    def comment_params
        params.require(:comment).permit(:content)
    end
end