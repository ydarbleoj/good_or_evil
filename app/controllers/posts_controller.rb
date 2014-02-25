class PostsController < ApplicationController

  before_action :authenticate_user!

  def index
    @posts = Post.all


  end

  def new
    @post = current_user.posts.new
  end


  def create
    post_params = params.require(:post).permit(:text_overlay, :photo, :photo_link)
    @post = Post.create(post_params)
    AWS.config({
                 :access_key_id     => ENV['S3_KEY'],
                 :secret_access_key => ENV['S3_SECRET']
    })
    #The s3 variable is creating a new connection to the S3 cloud storage.
    s3 = AWS::S3.new
    bucket_name = "goodevil" #This is the repository for images on the amazon account.
    "public#{@post.photo.url}"
    File.basename("public#{@post.photo.url}")
    bucket = s3.buckets[bucket_name]
    s3.buckets["goodevil"].objects[File.basename("public#{@post.photo.url}")].write(:file => "public#{@post.photo.url}")
    @post.update_attributes(photo_link: "https://s3.amazonaws.com/goodevil/"+"#{@post.photo.filename}")

    File.delete("#{Rails.root}/public#{@post.photo.url}")

    redirect_to root

  end

  def show
    @post = Post.find(params[:id])

  end

  def create_comment
    comment_params = params.require(:comment).permit(:body, :post_id)
    @comment = Comment.create(comment_params)
    post = Post.find(comment_params["post_id"])
    respond_to do |f|
      # f.html
      f.json { render :json => @comment, only: [:id, :body, :post_id]}
    end

  end

  def like
    like_params = params.require(:like).permit(:good, :likeable_id, :likeable_type)
    like = Like.create(like_params)
    if like_params["likeable_type"] == "Post"
      post = Post.find(like_params["likeable_id"])
      good_count = post.likes.where(good:true).count
      evil_count = post.likes.where(good:false).count
    elsif like_params["likeable_type"] == "Comment"
      comment = Comment.find(like_params["likeable_id"])
      good_count = comment.likes.where(good:true).count
      evil_count = comment.likes.where(good:false).count
    end
    @like_count = {good_count: good_count, evil_count: evil_count}
    respond_to do |f|
      f.json { render :json => @like_count }
    end
  end


  def edit
  end

  def update
    @post = Post.find(params[:id])
  end

  def destroy
  end

end
