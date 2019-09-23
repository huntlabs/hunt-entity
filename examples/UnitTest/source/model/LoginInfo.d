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
    
    @Column("update_time")
    int updated;
    
    int uid;

    @JoinColumn("uid")
    UserInfo uinfo;

    @JoinColumn("appid")
    AppInfo app;

    string location;
}