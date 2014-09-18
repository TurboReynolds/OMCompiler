#include <Core/Utils/extension/measure_time_rdtsc.hpp>

MeasureTimeValuesRDTSC::MeasureTimeValuesRDTSC(unsigned long long time) : MeasureTimeValues(), time(time), max_time(time) {}

MeasureTimeValuesRDTSC::~MeasureTimeValuesRDTSC() {}

std::string MeasureTimeValuesRDTSC::serializeToJson() const
{
  std::stringstream ss;
  ss << "\"time\":" << time << ",\"maxTime\":" << max_time;
  return ss.str();
}

MeasureTimeRDTSC::MeasureTimeRDTSC() : MeasureTime()
{
}

MeasureTimeRDTSC::~MeasureTimeRDTSC()
{
}

void MeasureTimeRDTSC::getTimeValuesStart(MeasureTimeValues *res)
{
  MeasureTimeValuesRDTSC *val = static_cast<MeasureTimeValuesRDTSC*>(res);
  unsigned long long time = RDTSC();
  val->time = time;
}

void MeasureTimeRDTSC::getTimeValuesEnd(MeasureTimeValues *res)
{
  unsigned long long time = RDTSC();
  MeasureTimeValuesRDTSC *val = static_cast<MeasureTimeValuesRDTSC*>(res);
  val->time = time;
}

MeasureTimeValues* MeasureTimeRDTSC::getZeroValuesP()
{
  return new MeasureTimeValuesRDTSC(0);
}

void MeasureTimeValuesRDTSC::add(MeasureTimeValues *values)
{
  MeasureTimeValuesRDTSC *val = static_cast<MeasureTimeValuesRDTSC*>(values);
  time += val->time;

  if( val->time > max_time )
    max_time = val->time;
}

void MeasureTimeValuesRDTSC::sub(MeasureTimeValues *values)
{
  MeasureTimeValuesRDTSC *val = static_cast<MeasureTimeValuesRDTSC*>(values);
  if(time > val->time)
    time -= val->time;
  else
    time = 0;
}

void MeasureTimeValuesRDTSC::div(int counter)
{
  time = time / counter;
}

#if defined(_MSC_VER)

#if defined(__i386__) || defined(__x86_64__)
unsigned long long MeasureTimeRDTSC::RDTSC()
{
  return _rdtsc();
}
#else
unsigned long long MeasureTimeRDTSC::RDTSC()
{
  throw std::runtime_error("No time measurement for this processor arch.");
  return 0;
}
#endif // defined(__i386__) || defined(__x86_64__)
#else
#if defined(__i386__)
unsigned long long MeasureTimeRDTSC::RDTSC()
{
  unsigned long long res;
  asm volatile (".byte 0x0f, 0x31" : "=A" (res));
  return res;
}

#elif defined(__x86_64__)
unsigned long long MeasureTimeRDTSC::RDTSC()
{
  unsigned hi, lo;
  __asm__ __volatile__ ("rdtsc" : "=a"(lo), "=d"(hi));
  return ((unsigned long long) lo) | (((unsigned long long) hi) << 32);
}

#else
unsigned long long MeasureTimeRDTSC::RDTSC()
{
  throw std::runtime_error("No time measurement for this processor arch.");
  return 0;
}

#endif //defined(__i386__)

#endif //defined(_MSC_VER)