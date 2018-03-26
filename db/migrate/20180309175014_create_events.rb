class CreateEvents < ActiveRecord::Migration[5.0]
  def change
    create_table :events do |t|
      t.integer :tournament_id
      t.string :name, { null: false }
      t.string :challonge_link

      t.timestamps
    end
  end
end
