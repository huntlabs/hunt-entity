module model.LoginInfo;

import hunt.entity;
import model.UserInfo;
import model.AppInfo;



@Table("LoginInfo")
class LoginInfo : Model
{
    mixin MakeModel;

    @AutoIncrement @PrimaryKey 
    int id;

    int create_time;
    int update_time;
    
    // int uid;
    @JoinColumn("uid")
    UInfo uinfo;

    @JoinColumn("appid")
    AppInfo app;
}