class AddDbSchema < ActiveRecord::Migration[5.2]
  def change
    # These are extensions that must be enabled in order to support this database
    enable_extension "plpgsql"
  
    create_table "authentications", force: :cascade do |t|
      t.string "resource_type"
      t.integer "resource_id"
      t.string "name"
      t.string "authtype"
      t.string "username"
      t.string "password"
      t.string "status"
      t.string "status_details"
      t.bigint "tenant_id", null: false
      t.index ["resource_type", "resource_id"], name: "index_authentications_on_resource_type_and_resource_id"
      t.index ["tenant_id"], name: "index_authentications_on_tenant_id"
    end
  
    create_table "endpoints", force: :cascade do |t|
      t.string "role"
      t.integer "port"
      t.bigint "source_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.boolean "default", default: false
      t.string "scheme"
      t.string "host"
      t.string "path"
      t.bigint "tenant_id", null: false
      t.boolean "verify_ssl"
      t.text "certificate_authority"
      t.index ["source_id"], name: "index_endpoints_on_source_id"
      t.index ["tenant_id"], name: "index_endpoints_on_tenant_id"
    end
  
    create_table "source_types", force: :cascade do |t|
      t.string "name", null: false
      t.string "product_name", null: false
      t.string "vendor", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.jsonb "schema"
      t.index ["name"], name: "index_source_types_on_name", unique: true
    end
  
    create_table "sources", force: :cascade do |t|
      t.string "name", null: false
      t.string "uid", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.bigint "tenant_id", null: false
      t.bigint "source_type_id", null: false
      t.string "version"
      t.index ["source_type_id"], name: "index_sources_on_source_type_id"
      t.index ["tenant_id"], name: "index_sources_on_tenant_id"
      t.index ["uid"], name: "index_sources_on_uid", unique: true
    end
  
    create_table "tenants", force: :cascade do |t|
      t.string "name"
      t.text "description"
      t.string "external_tenant"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
  
    add_foreign_key "authentications", "tenants", on_delete: :cascade
    add_foreign_key "endpoints", "sources", on_delete: :cascade
    add_foreign_key "endpoints", "tenants", on_delete: :cascade
    add_foreign_key "sources", "source_types", on_delete: :cascade
    add_foreign_key "sources", "tenants", on_delete: :cascade
  end
end
