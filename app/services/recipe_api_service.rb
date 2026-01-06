class RecipeApiService
  BASE_URL = "http://localhost:3000/api/v1/recipes"

  def self.all
    response = client.get("")
    return [] unless response.success?
    JSON.parse(response.body).map { |data| ApiRecipe.new(data) }
  end

  def self.find(id)
    response = client.get(id.to_s)
    return nil unless response.success?
    ApiRecipe.new(JSON.parse(response.body))
  end

  def self.create(params, auth)
    client(auth).post("", { recipe: params }.to_json)
  end

  def self.update(id, params, auth)
    client(auth).put(id.to_s, { recipe: params }.to_json)
  end

  def self.destroy(id, auth)
    client(auth).delete(id.to_s)
  end

  private

  def self.client(auth = nil)
    Faraday.new(url: BASE_URL) do |f|
      f.request :json
      f.headers['Authorization'] = auth if auth
      f.headers['Accept'] = 'application/json'
      f.adapter Faraday.default_adapter
    end
  end
end