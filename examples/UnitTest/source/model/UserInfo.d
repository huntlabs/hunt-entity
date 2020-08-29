module model.UserInfo;

import model.AppInfo;
import hunt.entity;
import model.Car;
import model.IDCard;

@Table("UserInfo")
class UserInfo : Model {

    mixin MakeModel;

    @AutoIncrement @PrimaryKey 
    int id;


    @Column("nickname")
    @Length(0,50)
    string nickName;
    @Max(150)
    int age;

    @ManyToMany("uinfos")
    AppInfo[] apps;

    @OneToOne(IDCard.user.stringof)
    // @OneToOne("user",FetchType.LAZY)
    IDCard card;

    @OneToMany(Car.user.stringof, FetchType.EAGER)
    Car[] cars;
}

