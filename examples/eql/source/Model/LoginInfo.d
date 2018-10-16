module Model.LoginInfo;

import hunt.entity;
import Model.UserInfo;



@Table("LoginInfo")
class LoginInfo
{
    mixin MakeEntity;

    @AutoIncrement @PrimaryKey 
    int id;

    // int uid;
    int create_time;
    int update_time;
    
    @JoinColumn("uid")
    UInfo uinfo;
}