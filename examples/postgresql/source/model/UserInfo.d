module model.UserInfo;

import model.AppInfo;
import hunt.entity;
import model.Car;
import model.IDCard;

@Table("userinfo")
class UserInfo : Model {

    mixin MakeModel;

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
