module Model.UserInfo;

import hunt.entity;
import Model.LoginInfo;


@Table("UserInfo")
class UInfo  {

    mixin MakeEntity;

    @AutoIncrement @PrimaryKey 
    int id;


    @Column("nickname")
    string nickName;
    int age;

}
