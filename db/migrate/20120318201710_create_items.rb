class CreateItems < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.integer :user_id
      t.string :name
      t.text :description
      t.string :manufacturer
      t.string :seller
      t.float :lowest_price
      t.float :highest_price
      t.float :current_price
      t.datetime :price_updated_at
      t.string :asin

      t.timestamps
    end
  end
end
