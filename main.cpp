#include <gubg/naft/Range.hpp>
#include <gubg/mss.hpp>
#include <output.hpp>
#include <iostream>
#include <sstream>
#include <vector>
#include <list>
#include <cstring>

namespace  { 
    void assign(float &dst, const std::string &src) { dst = std::stof(src); }
    void assign(int &dst, const std::string &src) { dst = std::stoi(src); }
    void assign(char &dst, const std::string &src) { dst = std::stoi(src); }

    std::string to_str(float v){return std::to_string(v);}
    std::string to_str(int v){return std::to_string(v);}
    std::string to_str(char v){return std::to_string((int)v);}
} 

class Writer
{
public:
    Writer(std::ostream &os): os_(os) {}

    template <typename POD>
    bool enter(POD &pod, const std::string &name, const std::string &type)
    {
        MSS_BEGIN(bool);
        os() << "[" << name << ":" << type << "]{\n";
        ++level_;
        MSS_END();
    }

    template <typename POD>
    bool exit(POD &pod, const std::string &name, const std::string &type)
    {
        MSS_BEGIN(bool);
        --level_;
        os() << "}\n";
        MSS_END();
    }

    template <typename Optional>
    bool optional(Optional &optional, bool oc, const std::string &name, const std::string &type)
    {
        MSS_BEGIN(bool);
        if (!optional)
            return true;
        MSS_END();
    }

    template <typename Array>
    bool array(Array &array, bool oc, const std::string &name, const std::string &type)
    {
        MSS_BEGIN(bool);
        if (oc)
        {
            os() << "[" << name << ":" << type << "*](size:" << array.size() << "){\n";
            ++level_;
        }
        else
        {
            --level_;
            os() << "}\n";
        }
        MSS_END();
    }

    template <typename Value>
    bool leaf(Value &value, const std::string &name, const std::string &type)
    {
        MSS_BEGIN(bool);
        os() << "[" << name << ":" << type << "](value:" << to_str(value) << ")\n";
        MSS_END();
    }

private:
    std::ostream &os_;
    std::ostream &os()
    {
        os_ << std::string(2*level_, ' ');
        return os_;
    }
    unsigned int level_ = 0;
};

class Reader
{
public:
    Reader(const std::string &content)
    {
        range_stack_.emplace_back(content);
    }

    template <typename POD>
    bool enter(POD &pod, const std::string &name, const std::string &type)
    {
        MSS_BEGIN(bool, "");L(C(name)C(type));

        auto &range = range_stack_.back();

        std::string n,t;
        MSS(range.pop_tag(n,t));
        MSS(n == name);
        MSS(t == type);

        range_stack_.emplace_back();
        range.pop_block(range_stack_.back());

        std::memset(&pod, 0, sizeof(pod));

        MSS_END();
    }

    template <typename POD>
    bool exit(POD &pod, const std::string &name, const std::string &type)
    {
        MSS_BEGIN(bool, "");L(C(name)C(type));
        range_stack_.pop_back();
        MSS_END();
    }

    template <typename Optional>
    bool optional(Optional &optional, bool oc, const std::string &name, const std::string &type)
    {
        MSS_BEGIN(bool, "");L(C(name)C(type)C(oc));

        if (oc)
        {
            auto &range = range_stack_.back();
            auto sp = range.savepoint();

            std::string n,t;
            MSS(range.pop_tag(n,t));
            L(C(n)C(t));
            if (n == name)
            {
                MSS(t == type);
                L("Allocating optional");
                optional.emplace();
            }
        }
        else
        {
        }
        MSS_END();
    }

    template <typename Array>
    bool array(Array &array, bool oc, const std::string &name, const std::string &type)
    {
        MSS_BEGIN(bool, "");L(C(name)C(type)C(oc));

        if (oc)
        {
            auto &range = range_stack_.back();

            std::string n,t;
            MSS(range.pop_tag(n,t));
            MSS(n == name);
            MSS(t == type+"*");

            range_stack_.emplace_back();
            const auto attrs = range.pop_attrs();
            auto it = attrs.find("size");
            MSS(it != attrs.end());
            array.resize(std::stoul(it->second));
            L(C(array.size()));

            range.pop_block(range_stack_.back());
        }
        else
        {
            range_stack_.pop_back();
        }

        MSS_END();
    }

    template <typename Value>
    bool leaf(Value &value, const std::string &name, const std::string &type)
    {
        MSS_BEGIN(bool, "");L(C(name)C(type));

        auto &range = range_stack_.back();

        std::string n,t;
        MSS(range.pop_tag(n,t));
        MSS(n == name);
        MSS(t == type);

        const auto attrs = range.pop_attrs();
        auto it = attrs.find("value");
        MSS(it != attrs.end());
        assign(value, it->second);

        MSS_END();
    }

private:
    std::list<gubg::naft::Range> range_stack_;
};

int main()
{
    B b;
    b.a.resize(2);
    b.a[0].b.emplace(42);
    b.a[1].c.resize(3);

    std::ostringstream oss;
    {
        Writer writer{oss};
        dfs(b, "", writer);
    }

    std::cout << oss.str();

    B bb;

    Reader reader{oss.str()};
    dfs(bb, "", reader);

    std::ostringstream oss2;
    {
        Writer writer{oss2};
        dfs(bb, "", writer);
    }

    std::cout << oss.str();
    std::cout << oss2.str();

    return 0;
}
