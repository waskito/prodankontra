class Api::V1::VotesController < Api::V1::BaseApisController
  before_action :authenticate_user_json!, only: [:create]

  def index
    render_index
  end

  def create
    # This one can be simplified using metaprogramming
    case params["model_name"]
      when "Topic"
        item = Topic.find(params[:topic_id])
      when "Opinion"
        item = Opinion.find(params[:opinion_id])
    end

    if (item.user == current_user)
      head :unauthorized
    else
      type = params[:type]
      if type == "up"
        item.upvote_from current_user
      elsif type == "down"
        item.downvote_from current_user
      elsif type == "unvote"
        my_vote_status = if current_user.voted_up_on? item then :up else :down end
        if my_vote_status == :up then item.unliked_by current_user else item.undisliked_by current_user end
      end
      render_index
    end
  end

  private

  def render_index
    case params["model_name"]
      when "Topic"
        item = Topic.find(params[:topic_id])
      when "Opinion"
        item = Opinion.find(params[:opinion_id])
    end

    logger.info(item.inspect)
    up_vote = item.get_upvotes.count
    down_vote = item.get_downvotes.count
    if user_signed_in?
      if current_user.voted_for? item
        my_vote_status = if current_user.voted_up_on? item then :up else :down end
      else
        my_vote_status = :quo
      end
    else
      my_vote_status = :not_available
    end
    render json: {my_vote_status: my_vote_status, up_vote: up_vote, down_vote: down_vote}
  end
end
