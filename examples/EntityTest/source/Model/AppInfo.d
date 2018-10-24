module Model.AppInfo;

import hunt.entity;
import Model.UserInfo;

@Table("AppInfo")
class AppInfo  {

    mixin MakeEntity;

    @AutoIncrement @PrimaryKey 
    int id;


    string name;
    string desc;

    
    @JoinTable("UserApp")
    @JoinColumn("appid","id")
    @InverseJoinColumn("uid","id")
    @ManyToMany("apps")
    UserInfo[] uinfos;
}
