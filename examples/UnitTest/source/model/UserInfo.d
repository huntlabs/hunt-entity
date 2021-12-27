module model.UserInfo;

import model.AppInfo;
import model.Car;
import model.IDCard;

import hunt.entity;

import hunt.logging;

@Table("userinfo")
class UserInfo : Model {

    mixin MakeModel;

    @AutoIncrement @PrimaryKey 
    int id;


    @Column("nickname")
    @Length(0,50)
    string nickName;
    @Max(150)
    int age;

    @Transient
    string sex;

    @ManyToMany("uinfos")
    AppInfo[] apps;

    @OneToOne(IDCard.user.stringof)
    // @OneToOne("user",FetchType.LAZY)
    IDCard card;

    // @OneToMany(Car.user.stringof, FetchType.EAGER)
    // Car[] cars;

    override void onInitialized() {
        warningf("card is null : %s", card is null);
    }
}

