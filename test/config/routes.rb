# frozen_string_literal: true

Dummy::Application.routes.draw do
  root to: "application#index"
  get :deprecated, to: "application#deprecated"
  get :locals, to: "application#locals"
end
