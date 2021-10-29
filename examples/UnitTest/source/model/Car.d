module model.Car;

import hunt.entity;
import model.UserInfo;

@Table("car")
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



@Table("car")
class Car2 : Model {

    mixin MakeModel;

    @AutoIncrement @PrimaryKey 
    int id;


    string name;

    int uid;

    float price;
}
