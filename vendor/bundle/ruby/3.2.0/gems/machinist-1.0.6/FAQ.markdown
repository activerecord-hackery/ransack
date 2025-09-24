Machinist FAQ
=============
    
### My blueprint is giving me really weird errors. Any ideas?

If your object has an attribute that happens to correspond to a Ruby standard function, it won't work properly in a blueprint. 

For example:

    OpeningHours.blueprint do
      open { Time.now }
    end
    
This will result in Machinist attempting to run ruby's open command. To work around this use self.open instead.

    OpeningHours.blueprint do
      self.open { Time.now }
    end
