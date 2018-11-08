module Model.Car;

import Model.AppInfo;
import hunt.entity;
import Model.UserInfo;

@Table("car")
class Car  {

    mixin MakeEntity;

    @AutoIncrement @PrimaryKey 
    int id;


    string name;

    @ManyToOne()
    @JoinColumn("uid","id")
    UserInfo user;
}
