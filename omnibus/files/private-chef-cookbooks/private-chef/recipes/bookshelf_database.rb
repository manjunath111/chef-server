bookshelf_attrs = node['private_chef']['bookshelf']
postgres_attrs = node['private_chef']['postgresql']

# create users
private_chef_pg_user bookshelf_attrs['sql_user'] do
  password bookshelf_attrs['sql_password']
  superuser false
end

private_chef_pg_user bookshelf_attrs['sql_ro_user'] do
  password bookshelf_attrs['sql_ro_password']
  superuser false
end

private_chef_pg_database 'bookshelf' do
  owner bookshelf_attrs['sql_user']
  # This is used to trigger creation of the schema during install.
  # For upgrades, create a partybus migration to perform any schema changes.
  notifies :deploy, "private_chef_pg_sqitch[/opt/opscode/embedded/service/bookshelf/schema]", :immediately
end

private_chef_pg_user_table_access bookshelf_attrs['sql_user'] do
  database 'bookshelf'
  schema 'public'
  access_profile :write
end

private_chef_pg_user_table_access bookshelf_attrs['sql_ro_user'] do
  database 'bookshelf'
  schema 'public'
  access_profile :read
end

# Note that these migrations are only deployed during an initial install via the
# :deploy notification above.  Upgrades to existing installations must be managed
# via partybus migrations.
private_chef_pg_sqitch "/opt/opscode/embedded/service/bookshelf/schema" do
  hostname postgres_attrs['vip']
  port     postgres_attrs['port']
  username  postgres_attrs['db_superuser']
  password  postgres_attrs['db_superuser_password']
  database "bookshelf"
  action :nothing
end
