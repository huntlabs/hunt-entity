module model.Car;

import model.AppInfo;
import hunt.entity;
import model.UserInfo;

@Table("car")
class Car : Model {

    mixin MakeModel;

    @AutoIncrement @PrimaryKey 
    int id;


    string name;

    @ManyToOne()
    @JoinColumn("uid","id")
    UserInfo user;
}
