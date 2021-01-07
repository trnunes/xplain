Rails.application.routes.draw do

  get 'session/execute'
  get 'session/fetch_nested_relations'
  get 'session/calculate_extension'
  get 'session/search'
  get 'session/update_title'
  get 'session/list_sessions'
  get 'session/load_session'
  get 'session/create'
  get 'session/load_last_active_session'
  get 'session/save_session'
  get 'session/save_path'
  get 'session/endpoint'
  get 'session/close'
  get 'session/delete_set'
  get 'session/export'
  get 'session/execute_update'
  get 'session/load_all_resultsets'
  get 'session/domain'
  post 'session/execute'
  get 'session/execute_visual'
  get 'session/render_faceted_search'
  get 'session/apply_facet'
  get 'session/trace_subset_domains'
  get 'session/trace_item_domains'
  get 'session/render_page'
  get 'session/renderdomain'
  get 'session/render_view'
  get 'session/relations'
  get 'session/common_relations'
  get 'session/all_relations'
  get 'session/all_types'
  get 'session/instances'
  get 'session/select'
  get 'session/get_level'
  get 'session/search'
  get 'session/set_endpoint'
  get 'session/namespace'
  post 'session/namespace'  
  get 'session/project'
  post 'session/index'
  get 'session/new'
  get 'help/index'
  get 'welcome/index'
  root 'welcome#index'
  
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
