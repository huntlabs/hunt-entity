module Model.UserInfo;

import hunt.entity;


@Table("UserInfo")
class UInfo  {

    mixin MakeEntity;

    @AutoIncrement @PrimaryKey 
    int id;


    @Column("nickname")
    string nickName;
    int age;
}
