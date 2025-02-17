// class capable of managing very diverse time-series data
// this sampler class is generalized to manage all e-Sense meter readings and keystroke data in-time with timestamps
class eventSampler{
  private IntList samples;
  private IntList timestamps;
  private int index;
  
  public eventSampler(){
    samples = new IntList();
    timestamps = new IntList();
    index = 0;
  }
  
  void add(int v, int t){
    samples.append(v);
    timestamps.append(t); 
  }
  
  void rewind(){
    index = 0;
  }
  
  // recursive function to find the soonest timestamp
  // i don't want to overcomplicate with a super edge case 3rd time marker in case the sync is bad so that's why case0 is LEQ
  // if we're querying LEQ than the current timestamp, just output the index and change nothing until we pass it
  // if we're querying between current and next timestamp, do a little naive linear ML to interpolate the value (this is not a ML course...)
  // if we're querying beyond the next timestamp, we're lagging behind so recurse until we "catch up" to maintain tempo
  int interpolateSample(int tq){
    if(samples.size()==0){
      return 0;
    }
    int next = (index + 1) % samples.size();
    if(tq==timestamps.get(index)){
      return samples.get(index);
    }
    else if(tq<timestamps.get(next)){
      //return samples[index];
      // time-distance mapping between sample[index] and sample[next] because millis() is annoying.
      int res = (int)lerp(samples.get(index),samples.get(next),(float)(tq-timestamps.get(index))/(float)(timestamps.get(next)-timestamps.get(index)));
      return res;
    }
    else{
      index = next;
      return samples.get(next);
    }
  }
  
  // gets the nearest sample temporally relative to a timestamp query in milliseconds
  int hasSample(int tq){
    int next = (index + 1) % samples.size();
    if(samples.size()==0){
      return -1;
    }
    if (timestamps.get(index) <= tq){
      int res = samples.get(index);
      index = next;
      return res;
    }
    return -1;
  }
}
