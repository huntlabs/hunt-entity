module model.LoginInfo;

import hunt.entity;
import model.UserInfo;
import model.AppInfo;



@Table("logininfo")
class LoginInfo : Model
{
    mixin MakeModel;

    @AutoIncrement @PrimaryKey 
    int id;

    int create_time;
    
    @Column("update_time")
    int updated;
    
    int uid;

    @JoinColumn("uid")
    UserInfo uinfo;

    int appid;

    @JoinColumn("appid")
    AppInfo app;

    string location;
}