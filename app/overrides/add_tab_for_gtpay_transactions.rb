Deface::Override.new(:virtual_path => "spree/admin/shared/_configuration_menu",
                     :name => "add_gtpay_transaction_link_configuration_menu",
                     :insert_bottom => "[data-hook='admin_configurations_sidebar_menu']",
                     :text => %q{<%= configurations_sidebar_menu_item Spree.t("gtpay_transactions"), admin_gtpay_transactions_path %>},
                     :disabled => false)