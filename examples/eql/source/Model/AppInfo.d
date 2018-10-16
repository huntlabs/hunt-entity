module Model.AppInfo;

import hunt.entity;


@Table("AppInfo")
class AppInfo  {

    mixin MakeEntity;

    @AutoIncrement @PrimaryKey 
    int id;


    string name;
    string desc;

}
