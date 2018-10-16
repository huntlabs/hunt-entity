module Model.LoginInfo;

import hunt.entity;
import Model.UserInfo;
import Model.AppInfo;



@Table("LoginInfo")
class LoginInfo
{
    mixin MakeEntity;

    @AutoIncrement @PrimaryKey 
    int id;

    int create_time;
    int update_time;
    
    // int uid;
    @JoinColumn("uid",true)
    UInfo uinfo;

    @JoinColumn("appid")
    AppInfo app;
}