module Model.UserInfo;

import hunt.entity;


@Table("UserInfo")
class UInfo  {

    mixin MakeEntity;

    @AutoIncrement @PrimaryKey 
    int id;

    int UserId;
    string UserName;

    @Column("NickName")
    string nickName;
    string Gender;
    string BirthDay;
    string Avatar;
    int Height;
    int Weight;
    string UserType;
        
}

@Table("FriendRelation")
class FrdRlt
{
    mixin MakeEntity;

    @AutoIncrement @PrimaryKey 
    int id;

    int MasterId;
    int SlaverId;
    int DelFlag;
    int AppId;
    int Time;
}