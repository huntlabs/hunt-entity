module model.AppInfo;

import hunt.entity;


@Table("AppInfo")
class AppInfo : Model {

    mixin MakeModel;

    @AutoIncrement @PrimaryKey 
    int id;


    string name;
    string desc;
}
