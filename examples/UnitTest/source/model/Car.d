module model.Car;

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
    @JoinColumn(Car.uid.stringof, UserInfo.id.stringof)
    UserInfo user;
}
