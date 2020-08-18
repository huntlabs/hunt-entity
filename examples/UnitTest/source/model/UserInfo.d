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

// FIXME: Needing refactor or cleanup -@zhangxueping at 2020-08-18T13:40:43+08:00
// 
    // @OneToOne()
    // @JoinColumn("id", "uid")
    @OneToOne("user",FetchType.LAZY)
    IDCard card;

    @OneToMany("user")
    Car[] cars;
}
