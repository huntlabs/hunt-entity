module Model.UserInfo;

import Model.AppInfo;
import hunt.entity;
import Model.Car;
import Model.IDCard;

@Table("userinfo")
class UserInfo  {

    mixin MakeEntity;

    @AutoIncrement @PrimaryKey 
    int id;


    @Column("nickname")
    string nickName;
    int age;

    @ManyToMany("uinfos")
    AppInfo[] apps;

    @OneToOne("user",FetchType.LAZY)
    IDCard card;

    @OneToMany("user")
    Car[] cars;
}
