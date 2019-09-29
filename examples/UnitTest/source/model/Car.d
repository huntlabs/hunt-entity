module model.Car;

import model.AppInfo;
import hunt.entity;
import model.UserInfo;

@Table("Car")
class Car : Model {

    mixin MakeModel;

    @AutoIncrement @PrimaryKey 
    int id;


    string name;

    int uid;

    @ManyToOne()
    @JoinColumn("uid","id")
    UserInfo user;
}
